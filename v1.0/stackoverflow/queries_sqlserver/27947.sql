
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    CROSS APPLY
        STRING_SPLIT(p.Tags, '>') AS t
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PopularTags AS (
    SELECT
        t.TagName AS PopularTag
    FROM
        Posts p
    CROSS APPLY
        STRING_SPLIT(p.Tags, '>') AS t
    GROUP BY
        t.TagName
    ORDER BY
        COUNT(*) DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TagStatistics AS (
    SELECT
        pt.PopularTag,
        COUNT(rp.PostId) AS PostsCount,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes,
        AVG(rp.CommentCount) AS AverageComments
    FROM
        PopularTags pt
    LEFT JOIN
        RankedPosts rp ON rp.Tags LIKE '%' + pt.PopularTag + '%'
    GROUP BY
        pt.PopularTag
)
SELECT
    ts.PopularTag,
    ts.PostsCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    ts.AverageComments,
    'Tag: ' + ts.PopularTag + 
    ' | Total Posts: ' + CAST(ts.PostsCount AS VARCHAR) + 
    ' | UpVotes: ' + CAST(ts.TotalUpVotes AS VARCHAR) +
    ' | DownVotes: ' + CAST(ts.TotalDownVotes AS VARCHAR) +
    ' | Average Comments: ' + CAST(ROUND(ts.AverageComments, 2) AS VARCHAR) AS Summary
FROM
    TagStatistics ts
ORDER BY
    ts.PostsCount DESC;
