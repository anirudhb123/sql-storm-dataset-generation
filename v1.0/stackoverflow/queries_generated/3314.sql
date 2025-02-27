WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id
    JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        pl.LinkTypeId = 1 -- Linked
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        SUM(CASE WHEN b.Name IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    ut.DisplayName AS TopUser,
    ut.UpVotesReceived,
    ut.DownVotesReceived,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ut ON ut.UpVotesReceived > 50
JOIN 
    PopularTags pt ON pt.TagCount > 5
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.ViewCount DESC, ut.UpVotesReceived DESC
LIMIT 50;

