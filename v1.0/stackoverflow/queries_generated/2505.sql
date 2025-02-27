WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- Count only BountyStart votes
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 5
),
RecentVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        v.UserId
    HAVING 
        COUNT(v.Id) > 3 
)
SELECT 
    pu.UserId,
    pu.DisplayName,
    pu.QuestionCount,
    pu.TotalBounties,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    COUNT(DISTINCT rp.Id) AS RecentQuestions,
    SUM(CASE WHEN rp.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
FROM 
    PopularUsers pu
LEFT JOIN 
    RecentVotes rv ON pu.UserId = rv.UserId
LEFT JOIN 
    RankedPosts rp ON pu.UserId = rp.OwnerUserId AND rp.rn <= 5
GROUP BY 
    pu.UserId, pu.DisplayName, pu.QuestionCount, pu.TotalBounties, rv.VoteCount
ORDER BY 
    pu.QuestionCount DESC, pu.TotalBounties DESC
LIMIT 10;
