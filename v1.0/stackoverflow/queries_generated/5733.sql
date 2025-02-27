WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), UserRankings AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(rp.Score) AS TotalScore, 
        SUM(rp.UpVotes) AS TotalUpVotes,
        SUM(rp.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
)

SELECT 
    ur.UserId, 
    ur.DisplayName, 
    ur.TotalScore, 
    ur.TotalUpVotes, 
    ur.TotalDownVotes,
    RANK() OVER (ORDER BY ur.TotalScore DESC) AS UserRank
FROM 
    UserRankings ur
LIMIT 10;
