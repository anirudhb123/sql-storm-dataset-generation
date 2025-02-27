WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    GROUP BY
        t.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        TopUsers,
        BadgeCount,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS RankByPostCount
    FROM
        TagStatistics
)

SELECT
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.AverageScore,
    tt.TopUsers,
    tt.BadgeCount
FROM
    TopTags tt
WHERE
    tt.RankByPostCount <= 10
ORDER BY
    tt.RankByPostCount;

WITH PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(h.Id) AS HistoryCount,
        MAX(p.CreationDate) AS LastActivityDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        PostHistory h ON h.PostId = p.Id
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        p.Id
)

SELECT
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.HistoryCount,
    pa.LastActivityDate
FROM
    PostActivity pa
WHERE
    pa.CommentCount > 5
ORDER BY
    pa.LastActivityDate DESC;

SELECT
    p.Title,
    p.Body,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(ph.ClosedCount, 0) AS ClosedHistoryCount
FROM
    Posts p
LEFT JOIN (
    SELECT
        PostId,
        COUNT(Id) AS CommentCount
    FROM
        Comments
    GROUP BY
        PostId
) c ON c.PostId = p.Id
LEFT JOIN (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes
    GROUP BY
        PostId
) v ON v.PostId = p.Id
LEFT JOIN (
    SELECT
        PostId,
        COUNT(Id) AS ClosedCount
    FROM
        PostHistory
    WHERE
        PostHistoryTypeId = 10
    GROUP BY
        PostId
) ph ON ph.PostId = p.Id
WHERE
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
ORDER BY
    TotalComments DESC, UpVotes DESC;
