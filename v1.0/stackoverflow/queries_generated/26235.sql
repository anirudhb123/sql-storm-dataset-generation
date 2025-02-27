WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostsRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1  -- Only considering questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.ViewCount, p.Score, u.DisplayName
),
HighScoredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        ScoreRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank = 1 AND Score > 10  -- Getting highest scored posts with score > 10
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount
    FROM
        RankedPosts
    WHERE 
        RecentPostsRank <= 10  -- Getting top 10 recent questions
)
SELECT 
    H.PostId,
    H.Title AS HighScoreTitle,
    H.Body AS HighScoreBody,
    H.OwnerDisplayName AS HighScoreOwner,
    H.Score AS HighScore,
    R.Title AS RecentTitle,
    R.Body AS RecentBody,
    R.OwnerDisplayName AS RecentOwner,
    R.Score AS RecentScore
FROM 
    HighScoredPosts H
JOIN 
    RecentPosts R ON R.OwnerDisplayName = H.OwnerDisplayName -- Match on owner for comparison
ORDER BY 
    H.Score DESC, R.ViewCount DESC;  -- Order by High Score then by View Count
