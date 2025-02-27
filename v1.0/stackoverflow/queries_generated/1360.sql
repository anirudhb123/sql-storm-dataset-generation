WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) as PostRank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM
        Posts p
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.UpvoteCount) AS TotalUpvotes,
        SUM(rp.DownvoteCount) AS TotalDownvotes
    FROM
        Users u
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY
        u.Id
),
TopUsers AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalScore,
        ups.AvgScore,
        ups.TotalUpvotes,
        ups.TotalDownvotes,
        RANK() OVER (ORDER BY ups.TotalScore DESC) as UserRank
    FROM
        UserPostStats ups
)
SELECT
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    tu.AvgScore,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    COALESCE((SELECT STRING_AGG(t.TagName, ', ') 
              FROM Tags t 
              JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')) 
              WHERE p.OwnerUserId = tu.UserId), 'No Tags') AS PopularTags
FROM
    TopUsers tu
WHERE
    tu.UserRank <= 10
ORDER BY
    tu.TotalScore DESC, tu.DisplayName;
