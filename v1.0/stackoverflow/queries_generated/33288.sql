WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        r.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Id AS PostId, 
    p.Title,
    u.DisplayName AS OwnerName,
    COALESCE(pb.UpVotes, 0) AS UpVotes,
    COALESCE(pb.DownVotes, 0) AS DownVotes,
    COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubs.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ih.EditCount, 0) AS TotalEdits,
    ih.LastEditDate,
    ARRAY_AGG(t.TagName) AS Tags
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVotes pb ON pb.PostId = p.Id
LEFT JOIN 
    UserBadges ubs ON ubs.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistorySummary ih ON ih.PostId = p.Id
LEFT JOIN 
    LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag
WHERE 
    p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31' -- filter by creation date
GROUP BY 
    p.Id, u.DisplayName, pb.UpVotes, pb.DownVotes, ubs.GoldBadges, ubs.SilverBadges, ubs.BronzeBadges, ih.EditCount, ih.LastEditDate
ORDER BY 
    p.Id DESC;
