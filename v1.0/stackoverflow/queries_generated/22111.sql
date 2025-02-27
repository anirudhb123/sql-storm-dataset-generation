WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownVotes,
        RANK() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(v.VoteTypeId = 2, 0)) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pwv.PopularityScore,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate) AS PostAbsoluteRank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ViewCount,
            COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0), 1) * 0.5 +
            COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0), 1) * -0.5 AS PopularityScore
        FROM Votes v
        GROUP BY PostId
    ) pwv ON p.Id = pwv.PostId
), RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalCommentScore,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        RANK() OVER (ORDER BY ua.TotalCommentScore DESC) AS CommentRank
    FROM UserActivity ua
)
SELECT 
    pu.UserId,
    pu.DisplayName,
    pu.PostCount,
    pu.TotalCommentScore,
    pu.TotalUpVotes,
    pu.TotalDownVotes,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.PopularityScore,
    CASE 
        WHEN pu.TotalUpVotes > pu.TotalDownVotes THEN 'Positive Influence'
        ELSE 'Negative Influence' 
    END AS InfluenceType
FROM 
    RankedUsers pu
JOIN 
    PostStatistics p ON pu.UserId = p.PostId
WHERE 
    pu.VoteRank <= 10
    AND (p.ViewCount > 100 OR pu.TotalCommentScore > 5)
ORDER BY 
    pu.TotalCommentScore DESC, p.PopularityScore DESC;
