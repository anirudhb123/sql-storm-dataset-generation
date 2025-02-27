WITH TopTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering questions
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Only questions
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 -- BountyClose votes
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        PH.CreationDate AS LastEditDate,
        PH.UserDisplayName AS LastEditor
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    ORDER BY 
        P.CreationDate DESC
    LIMIT 20
)
SELECT 
    T.TagName,
    T.TagCount,
    UR.UserId,
    UR.DisplayName AS UserName,
    UR.Reputation,
    UR.TotalQuestions,
    UR.TotalBounties,
    RA.PostId,
    RA.Title AS PostTitle,
    RA.OwnerDisplayName,
    RA.CreationDate AS PostCreationDate,
    RA.Score AS PostScore,
    RA.ViewCount AS PostViewCount,
    RA.LastEditor,
    RA.LastEditDate
FROM 
    TopTags T
JOIN 
    UserReputation UR ON UR.TotalQuestions > 0 -- Only users with questions
JOIN 
    RecentActivity RA ON RA.Title ILIKE '%' || T.TagName || '%' -- Finding matching posts
ORDER BY 
    T.TagCount DESC, UR.Reputation DESC, RA.Score DESC;
