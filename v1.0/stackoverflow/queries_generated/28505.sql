WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
HighScoringTags AS (
    SELECT 
        t.TagName,
        AVG(v.Score) AS AvgScore
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.VoteTypeId = 2 -- Only considering upvotes
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(v.Id) > 5 -- For tags with more than 5 upvotes
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER(PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionOrder
    FROM 
        PostHistory ph
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    pt.TagCount,
    au.DisplayName AS ActiveUser,
    au.TotalViews,
    au.PostCount,
    ht.TagName,
    ht.AvgScore,
    phd.UserDisplayName AS RecentEditor,
    phd.CreationDate AS LastEditDate,
    phd.Comment AS EditComment
FROM 
    Posts p
JOIN 
    PostTagCounts pt ON p.Id = pt.PostId
JOIN 
    ActiveUsers au ON p.OwnerUserId = au.UserId
JOIN 
    HighScoringTags ht ON ht.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
LEFT JOIN 
    PostHistoryDetails phd ON p.Id = phd.PostId AND phd.RevisionOrder = 1
WHERE 
    p.Score > 10
ORDER BY 
    p.ViewCount DESC, pt.TagCount DESC;
