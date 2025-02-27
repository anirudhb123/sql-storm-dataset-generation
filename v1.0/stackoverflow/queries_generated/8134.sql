WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 10
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerReputation,
    COUNT(pc.Comment) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    Comments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId
WHERE 
    rp.ScoreRank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.OwnerReputation
ORDER BY 
    rp.Score DESC, rp.RecentRank ASC;
