WITH UserInteraction AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        EXTRACT(EPOCH FROM (MAX(p.CreationDate) - MIN(p.CreationDate))) / 3600 AS PostDurationInHours
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenCount,
        MAX(ph.CreationDate) AS LastModificationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.Score
),
FinalAnalysis AS (
    SELECT 
        ui.UserId, 
        ui.DisplayName, 
        ui.PostCount, 
        ui.TotalBadgeClass, 
        ui.UpVoteCount, 
        ui.DownVoteCount, 
        ui.PostDurationInHours,
        pa.PostId,
        pa.Title,
        pa.Score,
        pa.CommentCount,
        pa.CloseCount,
        pa.ReopenCount,
        pa.LastModificationDate,
        CASE 
            WHEN pa.Score > 0 THEN 'Positive'
            WHEN pa.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreClassification
    FROM 
        UserInteraction ui
    JOIN 
        PostAnalytics pa ON ui.UserId = pa.PostId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalBadgeClass,
    UpVoteCount,
    DownVoteCount,
    PostDurationInHours,
    PostId,
    Title,
    Score,
    CommentCount,
    CloseCount,
    ReopenCount,
    LastModificationDate,
    ScoreClassification
FROM 
    FinalAnalysis
WHERE 
    (UpVoteCount - DownVoteCount) > 10 
    AND PostCount > 3 
    AND TotalBadgeClass IS NOT NULL
ORDER BY 
    PostCount DESC, 
    TotalBadgeClass DESC, 
    PostDurationInHours ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
UNION ALL
SELECT 
    ui.UserId,
    ui.DisplayName,
    ui.PostCount,
    ui.TotalBadgeClass,
    ui.UpVoteCount,
    ui.DownVoteCount,
    ui.PostDurationInHours,
    NULL AS PostId,
    NULL AS Title,
    NULL AS Score,
    NULL AS CommentCount,
    NULL AS CloseCount,
    NULL AS ReopenCount,
    NULL AS LastModificationDate,
    'No Posts' AS ScoreClassification
FROM 
    UserInteraction ui
WHERE 
    ui.PostCount = 0
ORDER BY 
    DisplayName;
