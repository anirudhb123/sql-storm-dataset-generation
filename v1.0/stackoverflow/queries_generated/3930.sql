WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.UserId AS OwnerUserId,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        r.PostId, 
        r.Title, 
        r.CreationDate, 
        r.Score, 
        r.ViewCount, 
        r.AnswerCount, 
        r.OwnerName,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = r.PostId) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = r.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = r.PostId AND v.VoteTypeId = 3) AS DownvoteCount,
        (SELECT STRING_AGG(T.TagName, ', ') 
         FROM Tags T 
         WHERE T.Id IN (SELECT unnest(string_to_array(p.Tags, ','))::int)
         GROUP BY T.Id) AS TagsList
    FROM 
        RecentPosts r
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.UpvoteCount,
    pd.DownvoteCount,
    pd.OwnerName,
    CASE 
        WHEN pd.Score IS NULL THEN 'No score'
        WHEN pd.Score > 0 THEN 'Positive'
        WHEN pd.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Score_Category,
    pd.TagsList
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC
LIMIT 10
UNION ALL
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = p.Id) AS CommentCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
    U.DisplayName AS OwnerName,
    'Offline Post' AS Score_Category,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     WHERE T.Id IN (SELECT unnest(string_to_array(p.Tags, ','))::int)
     GROUP BY T.Id) AS TagsList
FROM 
    Posts p
JOIN 
    Users U ON p.OwnerUserId = U.Id
WHERE 
    p.CreationDate < NOW() - INTERVAL '30 days'
AND 
    p.Score < 0
ORDER BY 
    p.ViewCount DESC
LIMIT 10;
