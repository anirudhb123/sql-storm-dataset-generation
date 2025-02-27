WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS TopBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        PH.UserDisplayName AS ClosedBy,
        PH.CreationDate AS ClosedOn
    FROM 
        Posts p
    JOIN 
        PostHistory PH ON p.Id = PH.PostId 
    WHERE 
        PH.PostHistoryTypeId = 10 -- Posts that were closed
),
PostVoteCounts AS (
    SELECT 
        VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        VoteTypeId
),
TagSubQuery AS (
    SELECT 
        TagName, 
        COUNT(*) AS TagCount
    FROM 
        Tags
    WHERE
        TagName NOT LIKE '%[0-9]%' -- Exclude tags with numbers
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 1
),
UnusualTitles AS (
    SELECT 
        p.Title 
    FROM 
        Posts p 
    WHERE 
        p.Title LIKE '%?%' -- Titles containing '?'
    AND 
        NOT EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)) -- Not closed or reopened
)
SELECT 
    u.DisplayName,
    ub.BadgeCount,
    COALESCE(CP.ClosedBy, 'Not Closed') AS ClosedBy,
    COALESCE(CP.ClosedOn, 'N/A') AS ClosedOn,
    STRING_AGG(DISTINCT ts.TagName, ', ') AS AssociatedTags,
    ARRAY_AGG(DISTINCT ut.Title) AS UnusualTitles,
    rp.Score AS TopExcerptScore
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    ClosedPosts CP ON u.Id = CP.ClosedBy
LEFT JOIN 
    Tags ts ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE CONCAT('%', ts.TagName, '%'))
LEFT JOIN 
    UnusualTitles ut ON ut.Title IN (SELECT Title FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation >= 1000 -- Only users with a decent reputation
GROUP BY 
    u.DisplayName, ub.BadgeCount, CP.ClosedBy, CP.ClosedOn, rp.Score
ORDER BY 
    ub.BadgeCount DESC NULLS LAST, 
    TopExcerptScore DESC NULLS LAST;
