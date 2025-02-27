
WITH RecursiveTagQuestion AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS rnk
    FROM 
        Posts p
    JOIN 
        Tags t ON LOCATE(t.TagName, p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate, 
        ph.UserDisplayName,
        GROUP_CONCAT(DISTINCT pst.Name ORDER BY pst.Name SEPARATOR ', ') AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pst ON ph.PostHistoryTypeId = pst.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.UserDisplayName
),
RankedUserPosts AS (
    SELECT 
        rp.QuestionId,
        rp.TagName,
        rp.Title,
        us.DisplayName,
        us.TotalBadges,
        ROW_NUMBER() OVER (PARTITION BY rp.QuestionId ORDER BY us.VoteCount DESC) AS UserRank
    FROM 
        RecursiveTagQuestion rp
    LEFT JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
)
SELECT 
    tqp.Title,
    tqp.TagName,
    tqp.DisplayName,
    tqp.TotalBadges,
    rph.PostHistoryType,
    rph.CreationDate AS RecentActionDate
FROM 
    RankedUserPosts tqp
LEFT JOIN 
    RecentPostHistory rph ON tqp.QuestionId = rph.PostId
WHERE 
    tqp.UserRank = 1 
    AND (rph.PostHistoryType IS NOT NULL OR tqp.TagName IS NOT NULL)
ORDER BY 
    tqp.Title ASC, rph.CreationDate DESC;
