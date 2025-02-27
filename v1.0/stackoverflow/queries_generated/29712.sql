WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, -- Counting UpVotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- Counting DownVotes
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Posts a ON p.Id = a.ParentId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1  -- Only considering Questions
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Tags, p.OwnerUserId, p.AcceptedAnswerId
),
PopularTags AS (
    SELECT
        unnest(string_to_array(RTRIM(LTRIM(b.Tags)), ',')) AS Tag
    FROM
        Posts b
    WHERE
        b.PostTypeId = 1  -- Only Questions
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.CreationDate >= '2023-01-01'  -- Posts created in 2023
    GROUP BY
        u.Id, u.DisplayName
    ORDER BY
        TotalViews DESC
    LIMIT 10
)

SELECT
    rp.Title,
    rp.CreationDate,
    rp.Tags,
    tu.DisplayName AS TopUser,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.Tag AS PopularTag
FROM
    RankedPosts rp
JOIN
    TopUsers tu ON rp.OwnerUserId = tu.UserId
JOIN
    PopularTags pt ON rp.Tags LIKE '%' || pt.Tag || '%'  -- Finding popular tags in post tags
WHERE
    rp.Rank <= 5  -- Top 5 posts per tag
ORDER BY
    rp.CreationDate DESC;
