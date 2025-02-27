WITH TagUsage AS (
    SELECT
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 -- Only questions
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM
        TagUsage
),
PopularUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId IN (1, 2) -- Only questions and answers
    GROUP BY
        u.Id, u.DisplayName
    ORDER BY
        TotalViews DESC
    LIMIT 10
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(ah.HelpfulPostCount, 0) AS HelpfulPostCount,
        ah.AcceptanceRate
    FROM
        Posts p
    LEFT JOIN (
        SELECT
            a.ParentId AS PostId,
            COUNT(*) AS HelpfulPostCount,
            ROUND(COALESCE(SUM(CASE WHEN a.AcceptedAnswerId IS NOT NULL THEN 1 END)::FLOAT / NULLIF(COUNT(*), 0), 0), 2) AS AcceptanceRate
        FROM
            Posts a
        WHERE
            a.PostTypeId = 2 -- Only answers
        GROUP BY
            a.ParentId
    ) ah ON p.Id = ah.PostId
    WHERE
        p.PostTypeId = 1 -- Questions only
)
SELECT
    t.Tag,
    t.TagCount,
    pu.DisplayName AS PopularUser,
    ps.Title AS PopularPostTitle,
    ps.ViewCount,
    ps.HelpfulPostCount,
    ps.AcceptanceRate
FROM
    TopTags t
LEFT JOIN
    PopularUsers pu ON pu.UserId IS NOT NULL
LEFT JOIN 
    PostStats ps ON ps.ViewCount IS NOT NULL
WHERE
    t.TagRank <= 10 -- Top 10 tags
ORDER BY
    t.TagCount DESC, 
    ps.ViewCount DESC;
