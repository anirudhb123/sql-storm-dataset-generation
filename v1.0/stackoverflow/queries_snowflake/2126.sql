
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    AND 
        p.Score > 0
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pv.UpVotes, 0) - COALESCE(pv.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10' 
        ELSE 'Other' 
    END AS RankingCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 20
ORDER BY 
    rp.Rank;
