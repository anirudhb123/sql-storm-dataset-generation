WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON true
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 AND  -- Posts that are questions
        p.CreationDate >= DATEADD(year, -1, CURRENT_TIMESTAMP)  -- Last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank = 1  -- Get only the most recent post of each user
),
HighScorePosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        CommentCount,
        Tags,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        TopPosts
    WHERE 
        Score > (SELECT AVG(Score) FROM TopPosts)  -- Only high scoring questions
),
DetailedTopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.OwnerDisplayName,
        p.Score,
        p.CommentCount,
        p.Tags,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 2) AS UpVotes,  -- Count upvotes
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 3) AS DownVotes  -- Count downvotes
    FROM 
        HighScorePosts p
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    Score,
    CommentCount,
    Tags,
    UpVotes,
    DownVotes,
    CASE 
        WHEN Score > 50 THEN 'High Engagement'
        WHEN Score BETWEEN 20 AND 50 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    DetailedTopPosts
ORDER BY 
    Score DESC, CommentCount DESC;
