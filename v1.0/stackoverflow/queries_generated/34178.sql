WITH RecursivePostCTE AS (
    -- CTE to capture posts and their hierarchy (Answers to Questions)
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        P.ParentId,
        P.OwnerUserId,
        CAST(0 AS INT) AS Depth
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only Questions

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        P.ParentId,
        P.OwnerUserId,
        Depth + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostCTE R ON P.ParentId = R.PostId
)

SELECT 
    U.DisplayName AS User,
    COUNT(DISTINCT PP.PostId) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN PP.AcceptedAnswerId IS NOT NULL THEN PP.Id END) AS AcceptedAnswers,
    COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalClosures,
    COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalTitleEdits,
    RANK() OVER (ORDER BY COUNT(DISTINCT PP.PostId) DESC) AS PostRank,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed,
    MAX(COALESCE(PP.ViewCount, 0)) AS MaxViews,
    AVG(PP.ViewCount) AS AvgViews
FROM 
    Users U
JOIN 
    Posts PP ON U.Id = PP.OwnerUserId
LEFT JOIN 
    PostHistory PH ON PP.Id = PH.PostId
LEFT JOIN 
    Tags T ON PP.Tags LIKE '%' + T.TagName + '%'
LEFT JOIN 
    RecursivePostCTE RPC ON PP.Id = RPC.ParentId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    SUM(CASE WHEN PP.PostTypeId = 1 THEN 1 ELSE 0 END) > 5
ORDER BY 
    TotalPosts DESC;

WITH MostActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)

SELECT 
    P.PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS User,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
    P.ViewCount,
    ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS PostRow
FROM 
    Posts P
JOIN 
    MostActiveUsers U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate > NOW() - INTERVAL '1 month'
GROUP BY 
    P.PostId, P.Title, P.CreationDate, U.DisplayName, P.ViewCount
ORDER BY 
    P.CreationDate DESC;
