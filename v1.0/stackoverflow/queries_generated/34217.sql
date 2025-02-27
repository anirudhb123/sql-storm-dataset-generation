WITH RecursiveTagCTE AS (
    SELECT
        p.Id,
        p.Title,
        p.Tags,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Question posts only (PostTypeId = 1)
    
    UNION ALL
    
    SELECT
        p.Id,
        p.Title,
        p.Tags,
        rt.Level + 1
    FROM
        Posts p
    INNER JOIN RecursiveTagCTE rt ON rt.Id = p.ParentId
    WHERE
        p.PostTypeId = 2  -- Answer posts only (PostTypeId = 2)
),
UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        p.Title,
        ph.CreationDate,
        PHT.Name AS ChangeType,
        COUNT(*) AS ChangeCount
    FROM
        PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    INNER JOIN PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE
        ph.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY
        ph.PostId, p.Title, ph.CreationDate, PHT.Name
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM
        Users u
)
SELECT
    rt.Title AS QuestionTitle,
    rt.Tags AS QuestionTags,
    uvs.DisplayName AS UserName,
    uvs.TotalVotes,
    uvs.UpVotes,
    uvs.DownVotes,
    phs.ChangeType,
    phs.ChangeCount,
    pu.UserRank
FROM
    RecursiveTagCTE rt
LEFT JOIN UserVoteStats uvs ON rt.Id = uvs.UserId
LEFT JOIN PostHistoryStats phs ON rt.Id = phs.PostId
LEFT JOIN TopUsers pu ON uvs.UserId = pu.UserId
WHERE
    rt.Level <= 2  -- Limit to questions and direct answers only
    AND (uvs.TotalVotes IS NULL OR uvs.UpVotes > 10)  -- Include only users with UpVotes greater than 10
ORDER BY
    rt.Title, pu.UserRank;
