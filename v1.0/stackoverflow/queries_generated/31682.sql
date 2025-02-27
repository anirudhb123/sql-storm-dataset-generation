WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) as UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) OVER (PARTITION BY p.Id) as DownVoteCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) as CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 YEAR'
),
UserPostStats AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        COUNT(p.Id) as PostCount,
        SUM(p.ViewCount) as TotalViews,
        SUM(rp.Score) as TotalScore,
        AVG(rp.UpVoteCount - rp.DownVoteCount) as AverageVoteBalance
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalScore,
        AverageVoteBalance,
        RANK() OVER (ORDER BY TotalScore DESC) as UserRank
    FROM 
        UserPostStats
)

SELECT 
    tu.DisplayName, 
    tu.PostCount, 
    tu.TotalViews, 
    tu.TotalScore, 
    tu.AverageVoteBalance,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top Contributor'
        WHEN tu.UserRank <= 50 THEN 'Moderate Contributor'
        ELSE 'Emerging Contributor'
    END as ContributionLevel
FROM 
    TopUsers tu
WHERE 
    tu.PostCount > 10
ORDER BY 
    tu.TotalScore DESC;
