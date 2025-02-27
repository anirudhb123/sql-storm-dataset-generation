WITH RecursiveTagCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId = 2::smallint) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TaggedPosts AS (
    SELECT 
        rtc.TagId,
        pd.Id AS PostId,
        pd.Title,
        pd.CreationDate,
        pd.CommentCount,
        pd.UpvoteCount,
        pd.DownvoteCount,
        COALESCE(ut.Reputation, 0) AS UserReputation
    FROM 
        RecursiveTagCounts rtc
    JOIN 
        PostsTags pt ON rtc.TagId = pt.TagId
    JOIN 
        PostDetails pd ON pd.Id = pt.PostId
    LEFT JOIN 
        UserReputation ut ON ut.UserId = pd.OwnerUserId
)
SELECT 
    t.TagName,
    SUM(tp.CommentCount) AS TotalComments,
    SUM(tp.UpvoteCount) AS TotalUpvotes,
    SUM(tp.DownvoteCount) AS TotalDownvotes,
    AVG(tp.UserReputation) AS AvgUserReputation
FROM 
    TaggedPosts tp
JOIN 
    Tags t ON tp.TagId = t.Id
GROUP BY 
    t.TagName
ORDER BY 
    TotalUpvotes DESC
LIMIT 5;
