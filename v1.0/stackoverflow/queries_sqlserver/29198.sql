
WITH TagFrequency AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagFrequency
    WHERE 
        PostCount > 5 
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(ISNULL(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.QuestionCount,
    U.TotalBounty,
    T.TagName,
    T.PostCount
FROM 
    UserReputation U
JOIN 
    PopularTags T ON T.TagName IN (
        SELECT 
            value
        FROM 
            Posts P
        CROSS APPLY STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><')
        WHERE 
            P.OwnerUserId = U.UserId AND P.PostTypeId = 1
    )
WHERE 
    U.Reputation > 1000 
ORDER BY 
    U.Reputation DESC, T.PostCount DESC;
