WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerDisplayName,
        P.Tags,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Questions only
        AND P.CreationDate >= DATEADD(year, -1, GETDATE())  -- Questions created in the last year
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT RP.PostId) AS QuestionCount,
        SUM(RP.ViewCount) AS TotalViews
    FROM 
        Users U
    JOIN 
        RankedPosts RP ON U.Id = RP.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
    HAVING 
        COUNT(DISTINCT RP.PostId) > 5  -- Users who have asked more than 5 questions in the last year
),
FrequentTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS UsageCount
    FROM 
        Posts P
    JOIN 
        Tags T ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])  -- Split Tags
    WHERE 
        P.PostTypeId = 1  -- Questions only
    GROUP BY 
        T.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10  -- Top 10 Tags
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.QuestionCount,
    U.TotalViews,
    FT.TagName,
    FT.UsageCount,
    RP.Title,
    RP.CreationDate
FROM 
    TopUsers U
JOIN 
    RankedPosts RP ON U.UserId = RP.OwnerUserId
JOIN 
    FrequentTags FT ON FT.UsageCount = (
        SELECT MAX(UsageCount) 
        FROM FrequentTags
        WHERE TagName IN (SELECT UNNEST(string_to_array(substring(RP.Tags, 2, length(RP.Tags)-2), '><')))
    )
WHERE 
    RP.Rank = 1  -- Top question per user
ORDER BY 
    U.Reputation DESC, U.QuestionCount DESC;
