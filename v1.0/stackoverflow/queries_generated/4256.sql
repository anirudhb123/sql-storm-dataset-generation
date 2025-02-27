WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(CAST(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2) AS varchar(4000)), 'No Tags') AS CleanedTags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Title,
    rp.CleanedTags,
    rp.ViewCount,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive' 
        WHEN rp.Score < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS ScoreCategory,
    CASE 
        WHEN rp.rn = 1 THEN 'Most Recent Post'
        ELSE 'Other Post'
    END AS PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteStats pvs ON rp.Id = pvs.PostId
WHERE 
    rp.rn <= 3
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;
