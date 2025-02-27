WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.FavoriteCount,
        rp.OwnerDisplayName,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
        COALESCE(rv.DownVotes, 0) AS RecentDownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerDisplayName,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.FavoriteCount,
    pm.RecentVoteCount,
    pm.RecentUpVotes,
    pm.RecentDownVotes
FROM 
    PostMetrics pm
WHERE 
    pm.RankByViews <= 5 -- Get top 5 viewed posts per user
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
