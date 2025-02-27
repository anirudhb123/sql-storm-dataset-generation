WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(ah.AvgAnswerScore, 0) AS AvgAnswerScore,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            AVG(Score) AS AvgAnswerScore
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 -- Answers
        GROUP BY 
            ParentId
    ) ah ON p.Id = ah.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS RevisionCount
        FROM 
            RecursivePostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
),
FinalResults AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.AvgAnswerScore,
        ps.RevisionCount
    FROM 
        UserActivity ua
    JOIN 
        PostStats ps ON ua.UserId = ps.OwnerUserId
)

SELECT 
    fr.UserId,
    fr.DisplayName,
    COUNT(fr.PostId) AS TotalPosts,
    SUM(fr.Score) AS TotalScore,
    AVG(fr.Score) AS AvgScore,
    SUM(fr.AvgAnswerScore) AS TotalAvgAnswerScore,
    SUM(fr.RevisionCount) AS TotalRevisions,
    COALESCE(NULLIF(SUM(fr.ViewCount), 0), 'No Views') AS TotalViews
FROM 
    FinalResults fr
GROUP BY 
    fr.UserId, fr.DisplayName
ORDER BY 
    TotalPosts DESC, TotalScore DESC;
