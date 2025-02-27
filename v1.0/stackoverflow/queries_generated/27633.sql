WITH TopTags AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM
        Tags t
    JOIN
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]) 
    GROUP BY
        t.TagName
    HAVING
        COUNT(p.Id) > 100
),
ActiveUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        u.Reputation > 1000
    GROUP BY
        u.Id
),
PostHistoryMetrics AS (
    SELECT
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        COUNT(DISTINCT ph.PostId) AS EditedPostCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6, 24)  -- Considering only title, body edits and suggested edits
    GROUP BY
        ph.UserId
),
PostScoreAnalysis AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(ph.EditCount, 0) AS EditCount,
        COALESCE(au.ActivePostCount, 0) AS UserPostCount,
        COALESCE(au.TotalUpVotes, 0) AS UserUpVotes,
        COALESCE(au.TotalDownVotes, 0) AS UserDownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        PostHistoryMetrics ph ON p.OwnerUserId = ph.UserId
    LEFT JOIN
        ActiveUsers au ON p.OwnerUserId = au.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT
    t.TagName,
    COUNT(DISTINCT psa.PostId) AS TotalPosts,
    AVG(psa.Score) AS AverageScore,
    SUM(psa.CommentCount) AS TotalComments,
    AVG(psa.EditCount) AS AverageEdits,
    AVG(psa.UserPostCount) AS AverageUserPostCount,
    AVG(psa.UserUpVotes) AS AverageUserUpVotes,
    AVG(psa.UserDownVotes) AS AverageUserDownVotes
FROM
    TopTags t
JOIN
    PostScoreAnalysis psa ON psa.PostId IN (
        SELECT p.Id
        FROM Posts p
        WHERE p.Tags LIKE '%' || t.TagName || '%'
    )
GROUP BY
    t.TagName
ORDER BY
    TotalPosts DESC;
