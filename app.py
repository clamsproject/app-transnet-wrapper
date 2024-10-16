import os
import argparse
import logging

from clams import ClamsApp, Restifier
from mmif import Mmif, AnnotationTypes, DocumentTypes
from transnetv2 import TransNetV2

class TransnetWrapper(ClamsApp):

    def __init__(self):
        # Construct the absolute path to the weights directory
        current_dir = os.path.dirname(os.path.abspath(__file__))
        weights_path = os.path.join(current_dir, "transnetv2-weights")
        self.model = TransNetV2(weights_path)
        super().__init__()

    def _appmetadata(self):
        # see https://sdk.clams.ai/autodoc/clams.app.html#clams.app.ClamsApp._load_appmetadata
        # Also check out ``metadata.py`` in this directory. 
        # When using the ``metadata.py`` leave this do-nothing "pass" method here. 
        pass

    def _annotate(self, mmif: Mmif, **parameters) -> Mmif:
        for vd in mmif.get_documents_by_type(DocumentTypes.VideoDocument):
            _, single_frame_predictions, _ = self.model.predict_video(vd.location_path())
            new_view = mmif.new_view()
            self.sign_view(new_view, parameters)
            shots = self.model.predictions_to_scenes(single_frame_predictions)

            new_view.new_contain(AnnotationTypes.TimeFrame, timeUnit="frame", document=vd.id)
            for shot in shots:
                annotation = new_view.new_annotation(AnnotationTypes.TimeFrame)
                annotation.add_property("start",int(shot[0]))
                annotation.add_property("end", int(shot[1]))
                annotation.add_property("label", "shot")
        return mmif

def get_app():
    return TransnetWrapper()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", action="store", default="5000", help="set port to listen")
    parser.add_argument("--production", action="store_true", help="run gunicorn server")
    # add more arguments as needed
    # parser.add_argument(more_arg...)

    parsed_args = parser.parse_args()

    # create the app instance
    app = TransnetWrapper()

    http_app = Restifier(app, port=int(parsed_args.port))
    # for running the application in production mode
    if parsed_args.production:
        http_app.serve_production()
    # development mode
    else:
        app.logger.setLevel(logging.DEBUG)
        http_app.run()
