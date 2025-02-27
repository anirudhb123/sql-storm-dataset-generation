WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        PostCount,
        AnswerCount,
        QuestionCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, Reputation DESC) AS Rank
    FROM 
        UserStats
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation AS UserReputation,
    PT.TagName AS PopularTag,
    PT.PostCount AS TagPostCount
FROM 
    TopUsers TU
JOIN 
    PopularTags PT ON TU.UserId = (
        SELECT 
            P.OwnerUserId
        FROM 
            Posts P
        WHERE 
            P.Tags ILIKE '%' || PT.TagName || '%'
        LIMIT 1
    )
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank, PT.PostCount DESC;
