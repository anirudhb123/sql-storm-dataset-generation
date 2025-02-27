
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
    GROUP BY
        p.Id,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate
),
TopRatedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM
        RankedPosts rp
    WHERE
        rp.CommentRank <= 10
),
TagSummary AS (
    SELECT
        value AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><') 
    WHERE
        PostTypeId = 1
    GROUP BY 
        value
),
TopTags AS (
    SELECT
        ts.TagName,
        ts.PostCount,
        ROW_NUMBER() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM
        TagSummary ts
)
SELECT
    ttp.Title,
    ttp.CommentCount,
    ttp.UpVotes,
    ttp.DownVotes,
    tt.TagName
FROM
    TopRatedPosts ttp
JOIN
    TopTags tt ON ttp.Tags LIKE '%' + tt.TagName + '%'
ORDER BY
    ttp.UpVotes DESC,
    ttp.CommentCount DESC;
