#include "../task.h"
int test_code(TASK* t)
{
        int state;
        state = t->state;
        return state;
}

int test(void)
{
        current = current->next;
        return (test_code(current));
}

