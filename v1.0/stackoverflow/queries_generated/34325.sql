WITH RECURSIVE UserPostCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostCount
), 
QuestionTags AS (
    SELECT 
        P.Id AS PostId,
        TRIM(UNNEST(string_to_array(P.Tags, '>'))) AS Tag
    FROM 
        Posts P 
    WHERE 
        P.PostTypeId = 1  -- Questions
), 
TaggedQuestions AS (
    SELECT 
        QT.Tag,
        COUNT(*) AS QuestionCount
    FROM 
        QuestionTags QT
    GROUP BY 
        QT.Tag
)
SELECT 
    TQ.Tag,
    TQ.QuestionCount,
    U.DisplayName,
    U.Reputation,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    RANK() OVER (ORDER BY TQ.QuestionCount DESC) AS TagRank
FROM 
    TaggedQuestions TQ
JOIN 
    TopUsers U ON U.UserId = (SELECT OwnerUserId 
                                FROM Posts 
                                WHERE Id IN (SELECT PostId 
                                              FROM QuestionTags 
                                              WHERE Tag = TQ.Tag) 
                                GROUP BY OwnerUserId 
                                ORDER BY COUNT(*) DESC LIMIT 1)
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) AS B ON B.UserId = U.UserId
WHERE 
    TQ.QuestionCount > 10
ORDER BY 
    TQ.QuestionCount DESC, 
    Tag;
