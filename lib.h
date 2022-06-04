#pragma once

// Write your class definition here
#include <string>

enum FlowType {Continue, Break};

class Generator
{
    public:
        static int counter_label;
        static int counter_var;

        static void init()
        {
            counter_label = 0;
            counter_var = 0;
        }

        static std::string make_label()
        {
            std::string temp = "_label";
            temp += std::to_string(counter_label++);
            return temp;
        }

        static std::string make_var()
        {
            std::string temp = "_temp";
            temp += std::to_string(counter_var++);
            return temp;
        }
};

struct CodeNode
{
    CodeNode() : code(""), name(""), arrayIndex("") {}
    std::string code;
    std::string name;
    bool isArray = false;
    std::string arrayIndex;
};


struct LoopNode : CodeNode
{
    LoopNode() : CodeNode() {}
    void addFlow(std::string& statements, FlowType type, std::string flow){
        if(type == Continue)
            while(statements.find("continue") != std::string::npos)
                statements.replace(statements.find("continue"), 8, flow);
        else
            while(statements.find("break") != std::string::npos)
                statements.replace(statements.find("break"), 5, flow);
    }
};