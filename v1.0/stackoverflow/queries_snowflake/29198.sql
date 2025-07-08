
WITH TagFrequency AS (
    SELECT 
        TRIM(SPLIT_PART(SUBSTR(Tags, 2, LENGTH(Tags)-2), '><', seq)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 1000)) AS seq
    WHERE 
        PostTypeId = 1 
        AND SPLIT_PART(SUBSTR(Tags, 2, LENGTH(Tags)-2), '><', seq) IS NOT NULL
    GROUP BY 
        TRIM(SPLIT_PART(SUBSTR(Tags, 2, LENGTH(Tags)-2), '><', seq))
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
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
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
            TRIM(SPLIT_PART(SUBSTR(P.Tags, 2, LENGTH(P.Tags)-2), '><', seq))
        FROM 
            Posts P,
            TABLE(GENERATOR(ROWCOUNT => 1000)) AS seq
        WHERE 
            P.OwnerUserId = U.UserId AND P.PostTypeId = 1
            AND SPLIT_PART(SUBSTR(P.Tags, 2, LENGTH(P.Tags)-2), '><', seq) IS NOT NULL
    )
WHERE 
    U.Reputation > 1000 
ORDER BY 
    U.Reputation DESC, T.PostCount DESC;
