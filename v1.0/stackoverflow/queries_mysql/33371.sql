
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(t.TagName, 'Uncategorized') AS MainTag
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            p.Id,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS TagName
        FROM Posts p
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
            SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    ) t ON p.Id = t.Id
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount, p.AnswerCount, t.TagName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(*) AS NumberOfEdits,
        GROUP_CONCAT(DISTINCT ph.Comment SEPARATOR ', ') AS EditComments
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(b.Class) / NULLIF(COUNT(DISTINCT b.Id), 0), 0) AS AverageBadgeClass
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserPostRank,
        phs.NumberOfEdits,
        phs.EditComments,
        ur.TotalBadgeClass,
        ur.BadgeCount,
        ur.AverageBadgeClass
    FROM RankedPosts rp
    LEFT JOIN PostHistorySummary phs ON rp.Id = phs.PostId
    LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.UserPostRank,
    COALESCE(pd.NumberOfEdits, 0) AS TotalEdits,
    pd.EditComments,
    pd.TotalBadgeClass,
    pd.BadgeCount,
    pd.AverageBadgeClass,
    CASE 
        WHEN pd.Score > 100 THEN 'Highly Popular'
        WHEN pd.Score BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityCategory
FROM PostDetails pd
WHERE pd.UserPostRank <= 5 
ORDER BY pd.Score DESC, pd.CreationDate DESC
LIMIT 10 OFFSET 10;
