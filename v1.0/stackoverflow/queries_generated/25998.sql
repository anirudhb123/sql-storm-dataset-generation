WITH ProcessedTags AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        LOWER(t.TagName) AS TagName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS TagRank
    FROM
        Posts p
    JOIN
        UNNEST(string_to_array(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    JOIN
        Tags t ON t.TagName = tag
    WHERE
        p.PostTypeId = 1  -- Questions only
),
FilteredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes -- Up votes
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
),
TagStatistics AS (
    SELECT
        pt.TagName,
        COUNT(DISTINCT pp.PostId) AS PostCount,
        AVG(pp.TotalUpVotes) AS AverageUpVotes,
        SUM(pp.CommentCount) AS TotalComments
    FROM
        ProcessedTags pt
    JOIN
        FilteredPosts pp ON pt.PostId = pp.Id
    WHERE
        pt.TagRank = 1  -- Most relevant tag
    GROUP BY 
        pt.TagName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AverageUpVotes,
    ts.TotalComments,
    ROW_NUMBER() OVER (ORDER BY ts.PostCount DESC) AS TagRank
FROM 
    TagStatistics ts
ORDER BY 
    ts.PostCount DESC, ts.AverageUpVotes DESC;
