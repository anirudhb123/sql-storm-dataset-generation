WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY substring(Tags FROM 2 FOR length(Tags) - 2) ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Only questions
        AND p.Score IS NOT NULL
),
TagStatistics AS (
    SELECT
        unnest(string_to_array(substring(Tags FROM 2 FOR length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS QuestionCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS UpvotedCount
    FROM
        Posts
    WHERE
        PostTypeId = 1  -- Only questions
    GROUP BY
        Tag
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentsCount,
        COALESCE(MAX(cl.CreationDate), '1970-01-01') AS LastClosedDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Post Closed
    WHERE
        p.PostTypeId = 1  -- Only questions
    GROUP BY
        p.Id
),
FinalSelection AS (
    SELECT
        rp.PostId,
        rp.Title,
        ts.Tag,
        ts.QuestionCount,
        ts.UpvotedCount,
        ua.UserId,
        ua.DisplayName,
        ua.QuestionsAsked,
        ua.TotalUpvotes,
        ua.TotalDownvotes,
        pa.CommentsCount,
        pa.LastClosedDate
    FROM
        RankedPosts rp
    JOIN
        TagStatistics ts ON ts.Tag = ANY(string_to_array(substring(rp.Tags FROM 2 FOR length(rp.Tags) - 2), '><'))
    JOIN
        UserActivity ua ON ua.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    JOIN
        PostActivity pa ON pa.PostId = rp.PostId
    WHERE
        rp.Rank <= 5  -- Top 5 for each tag
)

SELECT
    f.PostId,
    f.Title,
    f.Tag,
    f.QuestionCount,
    f.UpvotedCount,
    f.UserId,
    f.DisplayName,
    f.QuestionsAsked,
    f.TotalUpvotes,
    f.TotalDownvotes,
    f.CommentsCount,
    f.LastClosedDate
FROM
    FinalSelection f
ORDER BY
    f.Tag, f.UpvotedCount DESC;
