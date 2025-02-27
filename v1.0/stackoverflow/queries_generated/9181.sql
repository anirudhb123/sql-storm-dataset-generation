WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(co.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
), UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.Id) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.UpVoteCount) AS AverageUpVotes,
        AVG(rp.DownVoteCount) AS AverageDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalScore,
    ups.TotalViews,
    ups.AverageUpVotes,
    ups.AverageDownVotes,
    CASE 
        WHEN ups.TotalPosts > 10 THEN 'Expert'
        WHEN ups.TotalPosts BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    UserPostStats ups
ORDER BY 
    ups.TotalScore DESC,
    ups.TotalViews DESC
LIMIT 100;
