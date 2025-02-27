WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        pt.Name AS PostTypeName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        unnest(string_to_array(Tags, '><'))
),
BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CombinedStats AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.OwnerDisplayName,
        fp.CommentCount,
        fp.UpVotes,
        fp.DownVotes,
        ts.TagName,
        bc.BadgeCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        TagStats ts ON fp.Tags LIKE '%' || ts.TagName || '%'
    LEFT JOIN 
        BadgeCounts bc ON fp.OwnerDisplayName = bc.UserId
)
SELECT 
    *,
    CASE 
        WHEN UpVotes - DownVotes > 10 THEN 'Highly Upvoted'
        WHEN UpVotes - DownVotes BETWEEN 1 AND 10 THEN 'Moderately Upvoted'
        ELSE 'Less Engaging'
    END AS EngagementLevel
FROM 
    CombinedStats
ORDER BY 
    UpVotes DESC, DownVotes ASC;
