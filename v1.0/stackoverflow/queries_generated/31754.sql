WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.Comment, 
        ph.PostHistoryTypeId, 
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
), UserBadgeCounts AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), TopTags AS (
    SELECT 
        td.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags td
    JOIN 
        Posts p ON p.Tags LIKE '%' || td.TagName || '%'
    GROUP BY 
        td.TagName
    HAVING 
        COUNT(p.Id) > 5
), PostsWithTopTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        tt.TagName
    FROM 
        Posts p
    JOIN 
        TopTags tt ON p.Tags LIKE '%' || tt.TagName || '%'
), UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) -
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.BadgeCount,
    COALESCE(vs.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(vs.DownVotesCount, 0) AS DownVotesCount,
    COALESCE(vs.NetVoteCount, 0) AS NetVoteCount,
    COUNT(DISTINCT pwt.PostId) AS TotalPostsWithTags,
    STRING_AGG(DISTINCT tw.TagName, ', ') AS TopTags,
    MAX(rph.CreationDate) AS LastPostHistoryUpdate
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts b ON u.Id = b.UserId
LEFT JOIN 
    UserVoteSummary vs ON u.Id = vs.UserId
LEFT JOIN 
    PostsWithTopTags pwt ON pwt.PostId IN (
        SELECT DISTINCT ph.PostId 
        FROM RecursivePostHistory ph WHERE ph.rn = 1
    )
LEFT JOIN 
    RecursivePostHistory rph ON rph.PostId = pwt.PostId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName, u.Reputation, b.BadgeCount
ORDER BY 
    u.Reputation DESC, UpVotesCount DESC;
