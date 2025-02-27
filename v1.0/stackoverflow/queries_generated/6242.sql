WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3 -- Get top 3 latest questions per user
),
PostStats AS (
    SELECT 
        tp.*,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, -- Count of upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes  -- Count of downvotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName
)
SELECT 
    *,
    (ViewCount + UpVotes - DownVotes) AS EngagementScore -- Calculate engagement score
FROM 
    PostStats
ORDER BY 
    EngagementScore DESC
LIMIT 10; -- Limit to top 10 posts by engagement
