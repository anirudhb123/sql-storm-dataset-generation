
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        GROUP_CONCAT(DISTINCT SUBSTRING(p.Tags, 2, CHAR_LENGTH(p.Tags) - 2) SEPARATOR ', ') AS UniqueTags
    FROM 
        Posts p
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CommentCount
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS ClosedBy,
        ctr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment = CAST(ctr.Id AS CHAR)
    WHERE 
        ph.PostHistoryTypeId = 10  
)
SELECT 
    ub.DisplayName AS UserName,
    ub.BadgeCount,
    ub.BadgeNames,
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.AnswerCount,
    pa.CommentCount,
    pa.UniqueTags,
    cpd.CloseDate,
    cpd.ClosedBy,
    cpd.CloseReason
FROM 
    UserBadges ub
JOIN 
    Posts p ON p.OwnerUserId = ub.UserId
JOIN 
    PostAnalysis pa ON pa.PostId = p.Id
LEFT JOIN 
    ClosedPostDetails cpd ON cpd.PostId = p.Id
WHERE 
    ub.BadgeCount > 0
ORDER BY 
    ub.BadgeCount DESC, pa.ViewCount DESC;
