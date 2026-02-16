from pydantic import BaseModel
from typing import List, Dict, Any, Optional

class GenerateProblemRequest(BaseModel):
    topic: str
    difficulty: str
    count: int = 1

class SolveProblemRequest(BaseModel):
    expression: str

class HintRequest(BaseModel):
    expression: str
    current_step: int = 0

class MathProblem(BaseModel):
    id: str
    expression: str
    topic: str
    difficulty: str
    answer: str
    latex: str

class MathProblemResponse(BaseModel):
    problems: List[MathProblem]
    count: int
    topic: str
    difficulty: str

class MathStepResponse(BaseModel):
    step_number: int
    expression: str
    explanation: str
    latex: Optional[str] = None

class MathSolution(BaseModel):
    expression: str
    solution: str
    steps: List[MathStepResponse]
    hints: List[str]
    latex_steps: Optional[List[str]] = None
    graph_data: Optional[Dict[str, Any]] = None