
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(u.Reputation) AS AvgReputation,
        @rank := @rank + 1 AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    CROSS JOIN 
        (SELECT @rank := 0) r
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        PostCount,
        Questions,
        Answers,
        AvgReputation,
        Rank
    FROM 
        UserPostStats
    WHERE 
        Rank <= 10
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE((SELECT AVG(C.Score) 
                   FROM Comments C 
                   WHERE C.PostId = p.Id), 0) AS AvgCommentScore,
        COUNT(DISTINCT COALESCE(v.UserId, -1)) AS VoteCount,
        GROUP_CONCAT(DISTINCT COALESCE(b.Name, 'No Badge')) AS UserBadges,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PostMetrics AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.ViewCount,
        pa.Score,
        pa.AvgCommentScore,
        pa.VoteCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        pa.OwnerUserId
    FROM 
        PostActivity pa
    LEFT JOIN 
        Users u ON pa.OwnerUserId = u.Id
),
RankedPostMetrics AS (
    SELECT 
        *,
        @postRank := @postRank + 1 AS PostRank
    FROM 
        PostMetrics
    CROSS JOIN 
        (SELECT @postRank := 0) r
    ORDER BY Score DESC, ViewCount DESC
)
SELECT 
    tu.DisplayName AS TopUser,
    rpm.Title,
    rpm.CreationDate,
    rpm.ViewCount,
    rpm.Score,
    rpm.AvgCommentScore,
    rpm.VoteCount,
    rpm.OwnerDisplayName,
    rpm.OwnerReputation
FROM 
    TopUsers tu
JOIN 
    RankedPostMetrics rpm ON tu.UserId = rpm.OwnerUserId
WHERE 
    rpm.PostRank <= 10
ORDER BY 
    tu.Rank, rpm.Score DESC;
