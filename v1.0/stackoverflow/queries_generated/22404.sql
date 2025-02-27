WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),

UserRating AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN (u.UpVotes + 1) = 1 THEN NULL -- Special case for new users who just started voting
            ELSE (u.UpVotes::float / NULLIF(u.UpVotes + u.DownVotes, 0)) END AS UpvoteRatio
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        ur.UserId,
        ur.Reputation,
        ur.UpvoteRatio,
        COALESCE((
            SELECT 
                COUNT(DISTINCT bh.Id) 
            FROM 
                PostHistory bh 
            WHERE 
                bh.PostId = rp.PostId 
                AND bh.PostHistoryTypeId IN (10, 11) -- Closed, Reopened
        ), 0) AS StatusChangeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        UserRating ur ON ur.UserId = u.Id
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.CommentCount,
    pm.Reputation,
    pm.UpvoteRatio,
    pm.StatusChangeCount,
    CASE 
        WHEN pm.UpvoteRatio IS NULL THEN 'New User'
        WHEN pm.UpvoteRatio >= 0.75 THEN 'Highly Recommended'
        WHEN pm.UpvoteRatio >= 0.5 THEN 'Recommended'
        WHEN pm.UpvoteRatio >= 0.25 THEN 'Needs Improvement'
        ELSE 'Low Interaction'
    END AS UserInteractionLevel
FROM 
    PostMetrics pm
WHERE 
    pm.StatusChangeCount > 0
ORDER BY 
    pm.Score DESC, 
    pm.CommentCount DESC
LIMIT 20;

-- Optional: Aggregate votes for questions that have been closed, calculating a unique view into their interaction
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 AND p.Id IN (
        SELECT 
            bh.PostId 
        FROM 
            PostHistory bh 
        WHERE 
            bh.PostHistoryTypeId = 10 -- Specifically the closed posts
    )
GROUP BY 
    p.Id, p.Title
HAVING 
    COUNT(v.Id) > 0 -- Only include posts with votes
ORDER BY 
    TotalVotes DESC;

-- Final statement exploring relationships and linking closed questions with related tags and their clarification.
SELECT 
    t.TagName,
    COUNT(DISTINCT p.Id) AS ClosedQuestionsCount
FROM 
    Tags t
JOIN 
    Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
WHERE 
    p.PostTypeId = 1 
    AND EXISTS (
        SELECT 1 FROM PostHistory bh 
        WHERE 
            bh.PostId = p.Id 
            AND bh.PostHistoryTypeId = 10 -- Closed
    )
GROUP BY 
    t.TagName
ORDER BY 
    ClosedQuestionsCount DESC
LIMIT 10;
