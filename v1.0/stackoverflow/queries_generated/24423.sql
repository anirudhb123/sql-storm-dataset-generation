WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation, p.PostTypeId
), PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(month, -3, GETDATE()) -- Posts from the last three months
    GROUP BY 
        unnest(string_to_array(p.Tags, '><'))
    HAVING 
        COUNT(*) > 1
), UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 OR b.Class = 2 -- Gold or Silver badges
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Reputation,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.Tag AS PopularTag,
    ub.BadgeNames,
    ub.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.Tag || '%' -- Joining on contained tags
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.rn <= 10 -- Top 10 posts per type
    AND (rp.UpVotes - rp.DownVotes) > 10  -- Ensure posts with a net positive vote difference
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC, 
    rp.Reputation DESC;
