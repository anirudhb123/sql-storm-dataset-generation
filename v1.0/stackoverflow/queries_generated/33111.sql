WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        Score,
        CreationDate,
        OwnerUserId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostSummary AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        COALESCE(UPT.UserPostType, 'General') AS UserPostType,
        COALESCE(BadgeCount.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) BadgeCount ON p.OwnerUserId = BadgeCount.UserId
    LEFT JOIN (
        SELECT 
            UserId, 
            CASE 
                WHEN SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) > 5 THEN 'Frequent Poster'
                WHEN SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) <= 5 THEN 'Infrequent Poster'
                ELSE 'No Contributions'
            END AS UserPostType
        FROM 
            Posts 
        GROUP BY 
            UserId
    ) UPT ON p.OwnerUserId = UPT.UserId
),
ClosedPostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS ClosedReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
AggregatedPostData AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        COALESCE(SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveComments,
        COALESCE(SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativeComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score
)

SELECT 
    ps.Title AS PostTitle,
    ps.Score AS PostScore,
    ps.UserPostType,
    ps.BadgeCount,
    ps.UserRank,
    COALESCE(cpd.ClosedReason, 'Not Closed') AS ClosedReason,
    apd.PositiveComments,
    apd.NegativeComments,
    ph.Level AS HierarchyLevel
FROM 
    PostSummary ps
LEFT JOIN 
    ClosedPostDetails cpd ON ps.Id = cpd.Id
LEFT JOIN 
    AggregatedPostData apd ON ps.Id = apd.Id
LEFT JOIN 
    RecursivePostHierarchy ph ON ps.Id = ph.Id
WHERE 
    ps.BadgeCount > 0 OR ps.UserRank = 1
ORDER BY 
    ps.Score DESC, 
    ps.Title;
