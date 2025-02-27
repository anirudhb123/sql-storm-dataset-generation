WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.Rank,
    RP.CommentCount,
    RP.UpvoteCount,
    RP.DownvoteCount,
    COALESCE(B.Name, 'No Badge') AS BadgeName,
    CASE 
        WHEN RP.CommentCount = 0 THEN 'No Comments'
        ELSE 'Comments Available'
    END AS CommentStatus,
    CASE 
        WHEN RP.UpvoteCount > RP.DownvoteCount THEN 'Positive Sentiment'
        WHEN RP.UpvoteCount < RP.DownvoteCount THEN 'Negative Sentiment'
        ELSE 'Neutral Sentiment'
    END AS SentimentAnalysis
FROM 
    RankedPosts RP
LEFT JOIN 
    Badges B ON B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = RP.PostId)
WHERE 
    RP.Rank <= 5 
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC;

-- Use a correlated subquery to get the most recent edit date of each post.
WITH RecentEdits AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5)  -- Only consider Edit Title and Edit Body
    GROUP BY 
        PH.PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RE.LastEditDate,
    CASE 
        WHEN RE.LastEditDate IS NULL THEN 'No Edits'
        ELSE 'Edited'
    END AS EditStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentEdits RE ON RP.PostId = RE.PostId
WHERE 
    RP.Rank <= 3  -- Top 3 highest-scoring posts
    AND RP.CommentCount > 0  -- Must have comments
ORDER BY 
    RP.Score DESC;

-- Set operators to find posts that are popular versus controversial
SELECT 
    'Popular Posts' AS Category,
    RP.PostId,
    RP.Title,
    RP.Score
FROM 
    RankedPosts RP
WHERE 
    RP.UpvoteCount > RP.DownvoteCount
INTERSECT
SELECT 
    'Controversial Posts' AS Category,
    RP.PostId,
    RP.Title,
    RP.Score
FROM 
    RankedPosts RP
WHERE 
    RP.UpvoteCount < RP.DownvoteCount;

-- Outer join to see all posts and their badge owners, including those without badges.
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS BadgeOwner,
    B.Name AS BadgeName,
    CASE 
        WHEN B.Class = 1 THEN 'Gold'
        WHEN B.Class = 2 THEN 'Silver'
        WHEN B.Class = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeClass
FROM 
    Posts P
LEFT JOIN 
    Badges B ON B.UserId = P.OwnerUserId
LEFT JOIN 
    Users U ON U.Id = B.UserId
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
