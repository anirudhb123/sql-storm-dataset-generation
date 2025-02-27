WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.VoteCount) AS TotalVotes,
        AVG(rp.UpVotes) AS AvgUpVotes,
        AVG(rp.DownVotes) AS AvgDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.TotalScore,
    ur.TotalVotes,
    ur.AvgUpVotes,
    ur.AvgDownVotes
FROM 
    UserRankings ur
WHERE 
    ur.TotalVotes > 0
ORDER BY 
    ur.TotalScore DESC, ur.TotalVotes DESC
LIMIT 10;
