
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        pvs.UpVotes,
        pvs.DownVotes,
        pvs.TotalVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteSummary pvs ON rp.PostId = pvs.PostId
    WHERE 
        rp.rn <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    COALESCE(fp.Score, 0) AS EffectiveScore,
    COALESCE(fp.UpVotes, 0) AS EffectiveUpVotes,
    COALESCE(fp.DownVotes, 0) AS EffectiveDownVotes,
    COALESCE(fp.TotalVotes, 0) AS EffectiveTotalVotes,
    CASE 
        WHEN fp.UpVotes IS NULL AND fp.Score > 0 THEN 'Misleading'
        WHEN fp.DownVotes IS NULL AND fp.Score < 0 THEN 'Deceptive'
        ELSE 'Transparent'
    END AS TransparencyStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    (SELECT DISTINCT Tags FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', n.n), '<>', -1) AS Tags 
        FROM 
            Posts
        JOIN 
            (SELECT a.N + b.N * 10 + 1 n FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
        WHERE 
            n.n <= 1 + (LENGTH(Tags) - LENGTH(REPLACE(Tags, '<>', ''))) 
    ) AS TagData) AS DistinctTags ON true
ORDER BY 
    EffectiveScore DESC, EffectiveTotalVotes DESC;
