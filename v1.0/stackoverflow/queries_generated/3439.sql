WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        rn <= 3
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
PostWithVoteCounts AS (
    SELECT 
        tp.*,
        COALESCE(pvc.Upvotes, 0) AS Upvotes,
        COALESCE(pvc.Downvotes, 0) AS Downvotes
    FROM 
        TopPosts tp
    LEFT JOIN PostVoteCounts pvc ON tp.PostId = pvc.PostId
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Score,
    pwc.Upvotes,
    pwc.Downvotes,
    pwc.CreationDate,
    pwc.OwnerName,
    ROUND((pwc.Upvotes::decimal / NULLIF((pwc.Upvotes + pwc.Downvotes), 0)) * 100, 2) AS UpvotePercentage
FROM 
    PostWithVoteCounts pwc
WHERE 
    pwc.Upvotes + pwc.Downvotes > 0
ORDER BY 
    pwc.Score DESC, 
    UpvotePercentage DESC
LIMIT 10;

-- Perform outer join to also show posts without votes
SELECT
    COALESCE(pwc.PostId, tp.PostId) AS PostId,
    COALESCE(pwc.Title, tp.Title) AS Title,
    COALESCE(pwc.Score, 0) AS Score,
    COALESCE(pwc.Upvotes, 0) AS Upvotes,
    COALESCE(pwc.Downvotes, 0) AS Downvotes,
    COALESCE(pwc.CreationDate, tp.CreationDate) AS CreationDate,
    COALESCE(pwc.OwnerName, tp.OwnerName) AS OwnerName,
    ROUND((COALESCE(pwc.Upvotes, 0)::decimal / NULLIF((COALESCE(pwc.Upvotes, 0) + COALESCE(pwc.Downvotes, 0)), 0)) * 100, 2) AS UpvotePercentage
FROM 
    TopPosts tp
FULL OUTER JOIN PostWithVoteCounts pwc ON tp.PostId = pwc.PostId
ORDER BY 
    Score DESC, 
    UpvotePercentage DESC
LIMIT 10;
