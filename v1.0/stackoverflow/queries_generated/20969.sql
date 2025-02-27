WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActivityRanked AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        DENSE_RANK() OVER (ORDER BY AvgScore DESC) AS ScoreRank
    FROM 
        UserActivity
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalViews, 
        AvgScore, 
        AcceptedAnswers,
        LastPostDate,
        CASE 
            WHEN ViewRank = 1 AND ScoreRank = 1 THEN 'Top Contributor'
            WHEN ViewRank <= 10 THEN 'Top 10 by Views'
            WHEN ScoreRank <= 10 THEN 'Top 10 by Score'
            ELSE 'Regular Contributor'
        END AS ContributorCategory
    FROM 
        ActivityRanked
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(NULLIF(p.Body, ''), 'No content available') AS BodyPreview,
        pt.Name AS PostType,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserContributions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.PostId,
        p.Title,
        p.CreationDate,
        100.0 * COUNT(DISTINCT c.Id) / NULLIF(pc.PostCount, 0) AS CommentContributionPercentage
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        (SELECT OwnerUserId, COUNT(Id) AS PostCount FROM Posts GROUP BY OwnerUserId) pc ON u.Id = pc.OwnerUserId
    GROUP BY 
        u.Id, p.PostId, p.Title, p.CreationDate, pc.PostCount
),
FinalSummary AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.PostCount,
        p.PostId,
        p.Title,
        p.ViewCount,
        u.CommentContributionPercentage
    FROM 
        TopUsers t
    LEFT JOIN 
        PostInfo p ON t.PostCount > 0
    LEFT JOIN 
        UserContributions u ON t.UserId = u.UserId 
)

SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.PostCount,
    fs.PostId,
    fs.Title,
    fs.ViewCount,
    COALESCE(u.CommentContributionPercentage, 0) AS CommentContributionPercentage,
    CASE 
        WHEN fs.PostCount > 10 THEN 'Active User'
        ELSE 'Novice User'
    END AS UserType
FROM 
    FinalSummary fs
ORDER BY 
    fs.PostCount DESC, fs.ViewCount DESC NULLS LAST;
